module Api
  class NotificationController < ApplicationController
    include Api::Authenticatable
    
    before_action :set_notification, only: [:show, :update, :destroy, :mark_read]
    before_action :authorize_user!, only: [:show, :update, :destroy, :mark_read]

    # GET /api/notifications
    def index
      page = params[:page] || 1
      per_page = params[:per_page] || 20
      
      @notifications = current_user.notifications
        .order(created_at: :desc)
        .limit(per_page)
        .offset((page.to_i - 1) * per_page.to_i)
      
      render json: {
        notifications: @notifications,
        pagination: {
          page: page.to_i,
          per_page: per_page.to_i,
          total: current_user.notifications.count
        }
      }
    end

    # GET /api/notifications/:id
    def show
      render json: @notification
    end

    # POST /api/notifications
    def create
      @notification = current_user.notifications.build(notification_params)
      
      if @notification.save
        render json: @notification, status: :created, location: api_notification_url(@notification)
      else
        render json: { errors: @notification.errors.full_messages }, status: :unprocessable_entity
      end
    end

    # PATCH/PUT /api/notifications/:id
    def update
      if @notification.update(notification_params)
        render json: @notification
      else
        render json: { errors: @notification.errors.full_messages }, status: :unprocessable_entity
      end
    end

    # DELETE /api/notifications/:id
    def destroy
      @notification.destroy
      render json: { message: 'Notification deleted successfully' }, status: :ok
    end

    # PATCH /api/notifications/:id/mark_read
    def mark_read
      if @notification.update(read: true)
        render json: @notification
      else
        render json: { errors: @notification.errors.full_messages }, status: :unprocessable_entity
      end
    end

    private

    def set_notification
      @notification = Notification.find_by(id: params[:id])
      raise Api::Authenticatable::AuthenticationError, 'Notification not found' unless @notification
    end

    def authorize_user!
      authorize_notification!(@notification)
    end

    def notification_params
      params.require(:notification).permit(:message, :read)
    end
  end
end