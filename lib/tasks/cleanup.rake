namespace :cleanup do
  desc "Удаляет старые файлы из public старше 1 часа"
  task old_files: :environment do
    directory = "public"
    # cutoff_time = 1.hour.ago
    cutoff_time = 2.minutes.ago
    deleted_count = 0
    total_count = 0
    Dir.glob("#{directory}/*").each do |file_path|
      total_count += 1
      if File.file?(file_path)
        file_mtime = File.mtime(file_path)
        if file_mtime < cutoff_time
          File.delete(file_path)
          puts "Удален: #{File.basename(file_path)} (создан: #{file_mtime})"
          deleted_count += 1
        end
      end
    end
    puts "Очистка завершена. Удалено: #{deleted_count}/#{total_count} файлов"
  end
end
