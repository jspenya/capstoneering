def time_iterate(start_time, end_time, step, &block)
  begin
    yield(start_time)
  end while (start_time += step) <= end_time
end

c =
  Clinic.all.map{|c| 
    [c.clinic_schedules.map{ |cs| 
        ( 
          x = []
          time_iterate(cs.start_time, cs.end_time, 15.minutes) do |dt|
            x << [ c.name + " " + cs.day + " " + dt.strftime("%l:%M %p") ]
          end
          x.take(1)
        )
      }
    ] 
  }.flatten

# ap c
# ap c.grep /wednesday/i
# ap c.grep /thursday/i
# ap c.grep /friday/i

d = Date.today.beginning_of_month..Date.today.end_of_month.next_month

y = d.map{ |d|
  dow = d.strftime("%A")
  a_d = c.grep /#{dow}/i

  a_d.map{|a| a + " " + d.to_s }
  }

array_of_all_slots = y.flatten
ap array_of_all_slots

days_taken = Appointment.current_month.map{ |a| 
  cname = Clinic.find( a.clinic_id ).name
  t = a.schedule.strftime("%I:%M %p")
  aday = a.schedule.strftime("%A")
  adate = a.schedule.to_date.to_s

  [cname, aday, t, adate].join(" ")
}

# ap days_taken

available_slots = array_of_all_slots - days_taken

ap available_slots







# April 6 Wednesday 4:00 PM
# April 6 Wednesday 4:30 PM
# April 6 Wednesday 5:000 PM