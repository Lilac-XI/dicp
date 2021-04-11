# Use this file to easily define all of your cron jobs.
#
# It's helpful, but not entirely necessary to understand cron before proceeding.
# http://en.wikipedia.org/wiki/Cron

# Example:
#
# set :output, "/path/to/my/cron_log.log"
#
# every 2.hours do
#   command "/usr/bin/some_great_command"
#   runner "MyModel.some_method"
#   rake "some:great:rake:task"
# end
#
# every 4.days do
#   runner "AnotherModel.prune_old_records"
# end

# Learn more: http://github.com/javan/whenever
set :output, 'log/crontab.log'
env :PATH, ENV['PATH']
set :environment, :development

every 10.minutes do
    rake 'image_manager:list_image'
    rake 'image_manager:url_check'
    rake 'image_manager:png_jpg_change_test'
    rake 'image_manager:download_image'
end