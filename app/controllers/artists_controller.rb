class ArtistsController < ApplicationController
  include Pagy::Backend
  before_action :authenticate_artist!, except: [:index, :show]
  before_action :set_artist, only: [:edit, :update]

  def index
    @artists = Artist.approved
    @all_categories = Category.all
    @all_locations = Location.all

    if index_params[:start_date].present?
      @start_at = index_params[:start_date]
      @end_at = @start_at.to_date + 1.day
      @artists = Availability.available_artists(@start_at, @end_at)
      @start_date = @start_at
    else
      @start_date = Date.current
    end

    if index_params[:categories].present?
      if index_params[:filter_level] == "1"
        @artists = @artists.joins(:artist_categories)
          .where("category_id IN (?)", index_params[:categories])
          .distinct
          .reverse_order!
      else
        @artists = @artists.joins(:artist_categories)
          .where("category_id IN (?)", index_params[:categories])
          .group("artists.id")
          .having("count(*) >= (?)", index_params[:categories].size)
      end
    end

    if index_params[:location_id].present?
      @artists = @artists.where(location_id: index_params[:location_id])
    end

    @pagy, @artists = pagy_arel(@artists)
    respond_to do |format|
      format.html { }
      format.js { }
    end
  end

  def show
    @artist = Artist.find(show_params[:id])
    @start_date = show_params[:start_date]
    @sample_artists = Artist.approved.where("location_id = (?) AND id != (?)", @artist.location_id, @artist.id).sample(3)
    if !@artist.playlist.blank?
      @spotify_playlist = @artist.playlist.strip.insert(25, "embed/")
    else
      @spotify_playlist = ""
    end
    @availabilities = @artist.availabilities
    @bookings = @artist.bookings

    @reviews = Review.where(artist_id: @artist.id)
    @artist.reviews.blank? ? @average_review = 0 : @average_review = @artist.reviews.average(:rating).round(1)
  end

  def create
  end

  def update
    if update_params[:categories].present?
      ArtistCategory.where(artist: @artist).destroy_all

      ArtistCategory.transaction do
        update_params[:categories].each do |category|
          ArtistCategory.create!(category_id: category.to_i, artist: @artist)
        end
      rescue StandardError => error
        flash[:danger] = error.message
      end
    end

    if @artist.update(update_params.except(:categories))
      flash[:success] = "Vos informations ont bien été changées."
      redirect_to artist_bookings_path(artist_id: @artist.id)
    else
      @all_locations = Location.all
      @all_categories = Category.all
      flash[:danger] = "Erreur: " + @artist.errors.full_messages.join(" ")
      render :edit
    end
  end

  def destroy
  end

  def edit
    @all_locations = Location.all
    @all_categories = Category.all
  end

  private

  def set_artist
    @artist = current_artist
  end

  def index_params
    params.permit(:start_date, :filter_level, :location_id, categories: [])
  end

  def show_params
    params.permit(:id, :start_date)
  end

  def update_params
    params.require(:artist).permit(:artist_name, :description, :hourly_price, :location_id, :playlist, :avatar, pictures: [], categories: [])
  end
end
