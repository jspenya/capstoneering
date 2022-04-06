def time_iterate(start_time, end_time, step, &block)
  begin
    yield(start_time)
  end while (start_time += step) <= end_time
end

cs = ClinicSchedule.find_by(day: Date.today.strftime("%A"))
x = []
time_iterate(cs.start_time, cs.end_time, 15.minutes) do |dt|
    sched = Time.now.utc.to_date + dt.hour.hours + dt.min.minutes
    ClinicQueue.queue_today.create!( schedule: sched, clinic_id: cs.clinic.id, queue_type: 1, status: 1 )
    x << [ dt.strftime("%l:%M %p") ]
  end

ap x.flatten

slots_taken = Appointment.doctor_appointments_today.map{ |a|
  # byebug
  ClinicQueue.queue_today.create!( schedule: a.schedule.in_time_zone.asctime, user_id: a.user.id, clinic_id: a.clinic.id, queue_type: 2, status: 1 ) # if a.schedule > Time.now.utc
  [a.schedule.strftime("%l:%M %p")]
}

ap slots_taken.flatten

available_cq_slots = x.flatten - slots_taken.flatten

ap available_cq_slots
# c =
#   Clinic.all.map{|c| 
#     [c.clinic_schedules.map{ |cs| 
#         ( 
#           x = []
#           time_iterate(cs.start_time, cs.end_time, 15.minutes) do |dt|
#             x << [ c.name + " " + cs.day + " " + dt.strftime("%l:%M %p") ]
#           end
#           x
#         )
#       }
#     ] 
#   }.flatten

# # ap c
# # ap c.grep /wednesday/i
# # ap c.grep /thursday/i
# # ap c.grep /friday/i

# d = Date.today.beginning_of_month..Date.today.end_of_month

# y = d.map{ |d|
#   dow = d.strftime("%A")
#   a_d = c.grep /#{dow}/i

#   a_d.map{|a| a + " " + d.to_s }
#   }

# array_of_all_slots = y.flatten
# ap array_of_all_slots

# days_taken = Appointment.current_month.map{ |a| 
#   cname = Clinic.find( a.clinic_id ).name
#   t = a.schedule.strftime("%I:%M %p")
#   aday = a.schedule.strftime("%A")
#   adate = a.schedule.to_date.to_s

#   [cname, aday, t, adate].join(" ")
# }

# ap days_taken

# available_slots = array_of_all_slots - days_taken

# ap available_slots
