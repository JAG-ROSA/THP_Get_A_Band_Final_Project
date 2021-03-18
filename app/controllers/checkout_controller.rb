class CheckoutController < ApplicationController
  def create
    @user = current_user
    booking_id = params[:id].to_i
    @total = Booking.find(booking_id).total_price
    @session = Stripe::Checkout::Session.create(
      payment_method_types: ["card"],
      line_items: [
        {
          name: "Get a Band Stripe Checkout",
          amount: (@total * 100).to_i,
          currency: "eur",
          quantity: 1,
        },
      ],
      success_url: checkout_index_url + "?booking_id=#{booking_id}" + "&session_id={CHECKOUT_SESSION_ID}",
      cancel_url: root_url,
    )
    respond_to do |format|
      format.js
    end
  end
  def index
    @session = Stripe::Checkout::Session.retrieve(params[:session_id])
    @payment_intent = Stripe::PaymentIntent.retrieve(@session.payment_intent)
    @booking = Booking.find(params[:booking_id])
    @booking.update(status:"pending")
  end
end