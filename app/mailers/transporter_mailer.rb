class TransporterMailer < ApplicationMailer
  def send_planning
    @transporter = params[:transporter]
    @daily_quest = params[:daily_quest]

    @steps = @daily_quest.steps.with_all_rich_text.where(transporter: @transporter)

    return if @steps.empty?

    @date = l(@daily_quest.started_on, format: :complete_slash)

    attachment_name = "planning_#{@transporter.full_name}_#{@date}".parameterize(separator: '_')

    pdf = WickedPdf.new.pdf_from_string(
      render_to_string(
        template: 'daily_quests/transporters/steps/index',
        formats: [:pdf],
        layout: 'application'
      )
    )

    attachments["#{attachment_name}.pdf"] = pdf
    subject = I18n.t('transporter_mailer.send_planning.subject', date: @date)

    mail(to: @transporter.email, subject: subject)
  end
end
