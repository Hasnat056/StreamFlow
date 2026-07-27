# config/initializers/r2.rb

# aws-sdk-core defaults to attaching an SDK-computed checksum to every S3
# request; R2 rejects requests that carry both that and the Content-MD5
# checksum ActiveStorage/aws-sdk-s3 already send ("You can only specify one
# non-default checksum at a time"). Opt back into the old behavior for every
# S3 client in the app (this one and ActiveStorage's).
Aws.config.update(
  request_checksum_calculation: "when_required",
  response_checksum_validation: "when_required"
)

r2_config = Rails.application.credentials.r2

if r2_config.present?
  R2_CLIENT = Aws::S3::Client.new(
    access_key_id: r2_config[:access_key_id],
    secret_access_key: r2_config[:secret_access_key],
    endpoint: r2_config[:endpoint],
    region: "auto" # Cloudflare R2 requires region to be "auto"
  )

  R2_RESOURCE = Aws::S3::Resource.new(client: R2_CLIENT)
  S3_BUCKET = R2_RESOURCE.bucket(r2_config[:bucket_name])
else
  Rails.logger.warn "R2 credentials missing from Rails credentials!"
end
