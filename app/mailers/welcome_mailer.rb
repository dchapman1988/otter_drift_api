class WelcomeMailer < ApplicationMailer
  def welcome_email(player)
    @player = player
    @display_name = player.display_name_or_username

    mail(
      to: player.email,
      subject: "🦦 Welcome to Otter Drift! Get ready to collect some lilies!"
    )
  end
end
