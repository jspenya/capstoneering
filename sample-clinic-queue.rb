d1 = [500, 515, 530, 545, 600, 615]
d2 = [500, 515, 530, 545, 600, 615]

# d1.length.times do |l|
#   l = l + 15

#   puts l
# end
d1.each_with_index do |d,index|
  # byebug
  d = d + (index * 15)
  puts d
end
