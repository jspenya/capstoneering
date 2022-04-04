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
            x << [ c.name + " " + cs.day + " " + dt.strftime("%I:%M %p") ]
          end
          x
        )
      }
    ] 
  }.flatten

ap c
