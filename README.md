# README

This README would normally document whatever steps are necessary to get the
application up and running.

Things you may want to cover:

* Ruby version

* System dependencies

* Configuration

* Database creation

* Database initialization

* How to run the test suite

* Services (job queues, cache servers, search engines, etc.)

* Deployment instructions

* ...



## Business Context
You're building a **Real-Time Notification System** for a collaborative project management application. Users need to receive instant notifications when someone comments on their tasks, and they should be able to mark notifications as read/unread.

---

## Part 1: Ruby on Rails Backend Challenge (30 minutes)

### 📋 **Requirements**

Build a RESTful API for a notification system with the following features:

1. **Models & Relationships**:
   - User (already exists: id, name, email)
   - Notification (create this)
   - Associations and validations

2. **API Endpoints**:
   - GET /api/notifications - List user's notifications (with pagination)
   - POST /api/notifications - Create a notification 
   - PATCH /api/notifications/:id/mark_read - Mark notification as read
   - DELETE /api/notifications/:id - Delete notification

3. **Business Logic**:
   - Notifications have: message, read status, created timestamp
   - Users can only see their own notifications
   - Support real-time updates (WebSocket/ActionCable integration)

4. **Technical Requirements**:
   - Proper error handling and validation
   - JSON API responses
   - Database optimization (N+1 prevention)
   - Basic security (authorization)

### 🎯 **Deliverables** (Choose based on time):
Migration file for notifications table
Notification model with associations/validations  
Notifications controller with CRUD operations
Optional: ActionCable channel for real-time updates
Optional: Basic specs/tests