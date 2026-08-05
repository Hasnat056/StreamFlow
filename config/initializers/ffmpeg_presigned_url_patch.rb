# frozen_string_literal: true

# streamio-ffmpeg checks remote files exist via an HTTP HEAD request, but our
# presigned R2 URLs are signed for GET only (ActiveStorage's blob.url always
# signs GET) — R2 rejects the HEAD with a signature mismatch. Patch it to use
# a ranged GET instead, matching the verb the URL was actually signed for.
module FFMPEG
  class Movie
    private

    def head(location = @path, limit = FFMPEG.max_http_redirect_attempts)
      url = URI(location)
      return unless url.path

      http = Net::HTTP.new(url.host, url.port)
      http.use_ssl = url.scheme == "https"

      request = Net::HTTP::Get.new(url.request_uri)
      request["Range"] = "bytes=0-0"
      response = http.request(request)

      case response
      when Net::HTTPRedirection
        raise FFMPEG::HTTPTooManyRequests if limit == 0
        new_uri = url + URI(response["Location"])
        head(new_uri, limit - 1)
      else
        response
      end
    rescue SocketError, Errno::ECONNREFUSED
      nil
    end
  end
end
