# Preview all emails at http://localhost:3000/rails/mailers/transporter_mailer
class TransporterMailerPreview < ActionMailer::Preview
  def send_planning
    @transporter = Transporter.last
    @daily_quest = DailyQuest.last

    TransporterMailer
      .with(transporter: @transporter, daily_quest: @daily_quest)
      .send_planning
  end
end
