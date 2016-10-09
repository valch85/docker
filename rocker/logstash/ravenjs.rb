# encoding: utf-8
require "logstash/codecs/base"
require "logstash/codecs/line"
require "rack"
require "json"
require "uri"
require "sourcemap"
require "net/http"
require "net/https"
require "useragent"

# env GEM_HOME=/opt/logstash/vendor/bundle/jruby/1.9 GEM_PATH="" java -jar /opt/logstash/vendor/jar/jruby-complete-1.7.11.jar -S gem install sourcemap
# env GEM_HOME=/opt/logstash/vendor/bundle/jruby/1.9 GEM_PATH="" java -jar /opt/logstash/vendor/jar/jruby-complete-1.7.11.jar -S gem install useragent

# This codec may be used to decode (via inputs) and encode (via outputs) 
# full JSON messages.  If you are streaming JSON messages delimited
# by '\n' then see the `json_lines` codec.
# Encoding will result in a single JSON string.
class LogStash::Codecs::RavenJS < LogStash::Codecs::Base
  config_name "ravenjs"

  milestone 3

  # The character encoding used in this codec. Examples include "UTF-8" and
  # "CP1252".
  #
  # JSON requires valid UTF-8 strings, but in some cases, software that
  # emits JSON does so in another encoding (nxlog, for example). In
  # weird cases like this, you can set the `charset` setting to the
  # actual encoding of the text and Logstash will convert it for you.
  #
  # For nxlog users, you'll want to set this to "CP1252".
  config :charset, :validate => ::Encoding.name_list, :default => "UTF-8"

  public
  def register
    @converter = LogStash::Util::Charset.new(@charset)
    @converter.logger = @logger
  end
  
  public
  def decode(data)
    data = @converter.convert(data)

    begin
      event = JSON.parse(data)

      # we need to parse request_uri to get RavenJS data
      request_uri = URI.parse(event['request_uri'])
      raven_data = Rack::Utils.parse_nested_query(request_uri.query)
      # get rid of request_uri cause we don't need it
      event.delete('request_uri')

      # and then parse sentry data
      sentry_data = JSON.parse(raven_data['sentry_data'])
      # get rid of sentry_data cause we don't need it
      raven_data.delete('sentry_data')

      # populate raven data to root data object
      raven_data.each do |key, value|
        event[key] = value
      end

      # populate sentry data to root data object
      sentry_data.each do |key, value|
        event[key] = value
      end

      if event['exception']
        event['original_message'] = event['message']
        event['message'] = event['exception']['value']

        if event['exception']['type']
          event['message'] = "#{event['exception']['type']}: #{event['message']}"
        end
      end

      if event['stacktrace'] && event['stacktrace']['frames']
        frames = event['stacktrace']['frames'].map do |frame|
          map_frame(frame)
        end

        event['stacktrace'] = frames.map do |frame|
          file = frame['filename'].gsub(/^source_maps\/[^\/]+\//, '')
          " at #{frame['function']} (#{file}:#{frame['lineno']}:#{frame['colno']})"
        end

        unless frames.empty?
          frame = frames.first

          # populate topmost stacktrace line to root data object
          frame.each do |key, value|
            event[key] = value
          end

          event['message'] += event['stacktrace'].pop
        end

        event['stacktrace'] = ([event['message']] + event['stacktrace']).join("\n")
      end

      # parse user agent
      user_agent = UserAgent.parse(event['http_user_agent'])
      event['user_agent_parsed'] = {
        'browser' => user_agent.browser,
        'version' => user_agent.version,
        'platform' => user_agent.platform
      }

      yield LogStash::Event.new(event)
    rescue JSON::ParserError => e
      @logger.info("JSON parse failure. Falling back to plain-text", :error => e, :data => data)
      yield LogStash::Event.new("message" => data)
    rescue
      @logger.info("Parse failure. Falling back to plain-text", :error => e, :data => data)
      yield LogStash::Event.new("message" => data)
    end
  end # def decode

  public
  def encode(data)
    @on_event.call(data.to_json)
  end # def encode

  private
  def cache(key)
    @cache ||= {}

    unless @cache.has_key?(key)
      @cache[key] = yield
    end

    @cache[key]
  end

  private    
  def http_get(url)
    cache url do
      # p ['http get', url]
      begin
        uri = URI.parse(url)

        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE

        request = Net::HTTP::Get.new(uri.request_uri)
        response = http.request(request)

        response.body
      rescue Exception => e
        @logger.info("Failed to get url: #{url}", :error => e, :url => url)
        nil
      end
    end
  end

  private
  def fetch_sourcemap_url_from_content(content)
    sourcemap_url = nil

    content.split("\n").each do |line|
      if line.index("//@ sourceMappingURL=") == 0 || line.index("//# sourceMappingURL=") == 0
        sourcemap_url = line[21..-1].strip
        break
      end
    end

    sourcemap_url
  end

  private
  def fetch_sourcemap_from_file(url)
    cache "fetch_sourcemap_from_file_#{url}" do
      content = http_get(url)
      return unless content

      sourcemap_url = fetch_sourcemap_url_from_content(content)
      return unless sourcemap_url

      sourcemap_content = http_get(fetch_sourcemap_url_from_content(content))
      return unless sourcemap_content

      SourceMap::Map.from_json(sourcemap_content)
    end
  end

  private
  def get_mapping(url, lineno, colno)
    cache "get_mapping_#{url}_#{lineno}_#{colno}" do
      sourcemap = fetch_sourcemap_from_file(url)
      return unless sourcemap

      sourcemap.bsearch(SourceMap::Offset.new(lineno, colno))
    end
  end

  private
  def map_frame(frame)
    framedup = frame.dup
    mapping = get_mapping(framedup['filename'], framedup['lineno'], framedup['colno'])

    if mapping
      framedup['filename'] = mapping.source
      framedup['lineno'] = mapping.original.line
      framedup['colno'] = mapping.original.column
      framedup['function'] = mapping.name
    end

    framedup
  end

end # class LogStash::Codecs::RavenJS

