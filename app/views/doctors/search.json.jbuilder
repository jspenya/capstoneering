json.patients do
	json.array!(@patients) do |patient|
		json.lastname patient.lastname
		json.url patient_path(patient)
	end
end