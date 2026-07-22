# config/initializers/r2.rb

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
