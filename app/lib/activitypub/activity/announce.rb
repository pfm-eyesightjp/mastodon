# frozen_string_literal: true

class ActivityPub::Activity::Announce < ActivityPub::Activity
  def perform
    original_status   = status_from_uri(object_uri)
    original_status ||= fetch_remote_original_status

    return if original_status.nil? || delete_arrived_first?(@json['id'])

    status = Status.find_by(account: @account, reblog: original_status)

    return status unless status.nil?

    status = Status.create!(account: @account, reblog: original_status, uri: @json['id'])
    distribute(status)
    status
  end

  private

  def fetch_remote_original_status
    if object_uri.start_with?('http')
      ActivityPub::FetchRemoteStatusService.new.call(object_uri)
    elsif @object['url'].present?
      ::FetchRemoteStatusService.new.call(@object['url'])
    end
  end
end
