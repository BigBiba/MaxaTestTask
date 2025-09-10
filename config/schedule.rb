every 30.minutes do
  rake "cleanup:old_files"
  command "echo 'Запущена очистка файлов'"
end

every 1.day, at: "3:00 am" do
  rake "cleanup:old_files"
end
