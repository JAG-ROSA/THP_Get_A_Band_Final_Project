class BookingMailer < ApplicationMailer
  def customer_request(booking)
    @booking = booking
    @user = @booking.user
    mail(to: @user.email, subject: 'Demande de réservation envoyée') 
  end

  def artist_request(booking)
    @booking = booking
    @artist = @booking.artist
    mail(to: @artist.email, subject: 'Nouvelle demande de réservation') 
  end

  def customer_confirmation(booking)
    @booking = booking
    @user = @booking.user
    mail(to: @user.email, subject: 'Demande de réservation acceptée') 
  end

  def customer_cancellation(booking)
    @booking = booking
    @user = @booking.user
    mail(to: @user.email, subject: 'Demande de réservation refusée') 
  end
end