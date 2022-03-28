json.extract! patient, :id, :email, :firstname, :lastname, :birthdate, :gender, :role, :created_at, :updated_at
json.url patient_url(patient, format: :json)
