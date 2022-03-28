json.extract! appointment, :id, :user_id, :clinic_id, :schedule, :status, :created_at, :updated_at
json.url appointment_url(appointment, format: :json)
