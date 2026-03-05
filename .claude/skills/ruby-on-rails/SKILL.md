---
name: ruby-on-rails
description: Ruby on Rails 8 development with Hotwire (Turbo, Stimulus), Tailwind CSS, PostgreSQL, RSpec, and deployment patterns.
---

# Ruby on Rails Skill

## When to Activate
- Building web applications with Ruby on Rails
- Working with Hotwire (Turbo, Stimulus)
- Rails API-only backends
- Full-stack Rails with Tailwind CSS

## When Rails vs Next.js

| Use Case | Choose |
|----------|--------|
| Content-heavy apps, CMS, blogs | **Rails** |
| Admin panels, CRUD-heavy apps | **Rails** |
| Rapid prototyping, MVPs | **Rails** |
| Apps with complex real-time UI | **Next.js** |
| API consumed by mobile apps | Rails API or **FastAPI** |
| Dashboards with heavy charts | **Next.js** |

## Project Structure (Rails 8)

```
app/
  controllers/
    application_controller.rb
    api/
      v1/
        base_controller.rb
        users_controller.rb
  models/
    application_record.rb
    user.rb
    concerns/
  views/
    layouts/
    shared/
    components/          # ViewComponent
  services/              # Business logic
    user_registration.rb
  jobs/
    application_job.rb
  mailers/
  channels/              # Action Cable
  javascript/
    controllers/         # Stimulus controllers
    application.js
config/
  routes.rb
  database.yml
db/
  migrate/
  seeds.rb
spec/                    # RSpec tests
  models/
  requests/
  services/
  support/
  factories/
Dockerfile
docker-compose.yml
Gemfile
```

## Core Patterns

### Model with Validations
```ruby
class User < ApplicationRecord
  has_many :posts, dependent: :destroy
  has_many :comments, dependent: :destroy

  validates :email, presence: true, uniqueness: { case_sensitive: false },
                    format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :name, presence: true, length: { minimum: 2, maximum: 100 }

  scope :active, -> { where(active: true) }
  scope :recent, -> { order(created_at: :desc) }

  before_save :normalize_email

  private

  def normalize_email
    self.email = email.downcase.strip
  end
end
```

### Service Object
```ruby
class UserRegistration
  def initialize(params)
    @params = params
  end

  def call
    user = User.new(@params)

    ActiveRecord::Base.transaction do
      user.save!
      UserMailer.welcome_email(user).deliver_later
      create_default_settings(user)
    end

    Result.success(user)
  rescue ActiveRecord::RecordInvalid => e
    Result.failure(e.record.errors.full_messages)
  end

  private

  def create_default_settings(user)
    user.create_settings!(theme: "light", notifications: true)
  end
end
```

### Controller (RESTful)
```ruby
class Api::V1::UsersController < Api::V1::BaseController
  before_action :authenticate_user!
  before_action :set_user, only: [:show, :update, :destroy]

  def index
    @users = User.active.recent.page(params[:page]).per(20)
    render json: @users, each_serializer: UserSerializer
  end

  def create
    result = UserRegistration.new(user_params).call

    if result.success?
      render json: result.value, status: :created
    else
      render json: { errors: result.errors }, status: :unprocessable_entity
    end
  end

  private

  def set_user
    @user = User.find(params[:id])
  end

  def user_params
    params.require(:user).permit(:name, :email, :password)
  end
end
```

### Hotwire / Turbo Frames
```erb
<!-- app/views/posts/index.html.erb -->
<%= turbo_frame_tag "posts" do %>
  <div class="space-y-4">
    <% @posts.each do |post| %>
      <%= render post %>
    <% end %>
  </div>
  <%= link_to "Load more", posts_path(page: @page + 1),
      data: { turbo_frame: "posts" } %>
<% end %>
```

### Stimulus Controller
```javascript
// app/javascript/controllers/search_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "results"]
  static values = { url: String }

  async search() {
    const query = this.inputTarget.value
    if (query.length < 2) return

    const response = await fetch(`${this.urlValue}?q=${query}`)
    this.resultsTarget.innerHTML = await response.text()
  }
}
```

## Database & Migrations

```bash
# Generate migration
rails generate migration AddStatusToUsers status:integer default:0

# Run migrations
rails db:migrate

# Rollback
rails db:rollback STEP=1

# Seed data
rails db:seed
```

### N+1 Prevention
```ruby
# BAD: N+1
@posts = Post.all
@posts.each { |p| p.user.name }  # Fires query per post

# GOOD: Eager loading
@posts = Post.includes(:user, :comments).all

# GOOD: Strict loading (Rails 7+)
class Post < ApplicationRecord
  self.strict_loading_by_default = true
end
```

## Testing (RSpec)

```ruby
# spec/models/user_spec.rb
RSpec.describe User do
  describe "validations" do
    it { is_expected.to validate_presence_of(:email) }
    it { is_expected.to validate_uniqueness_of(:email).case_insensitive }
  end

  describe ".active" do
    it "returns only active users" do
      active = create(:user, active: true)
      create(:user, active: false)
      expect(User.active).to eq([active])
    end
  end
end

# spec/requests/api/v1/users_spec.rb
RSpec.describe "Api::V1::Users" do
  describe "POST /api/v1/users" do
    it "creates a user" do
      post "/api/v1/users", params: { user: attributes_for(:user) }
      expect(response).to have_http_status(:created)
      expect(json_response["email"]).to be_present
    end
  end
end
```

## Docker Deployment

```dockerfile
FROM ruby:3.3-slim AS base
WORKDIR /app
RUN apt-get update -qq && apt-get install -y libpq-dev
COPY Gemfile Gemfile.lock ./
RUN bundle install --without development test

FROM base AS production
COPY . .
RUN bundle exec rails assets:precompile
EXPOSE 3000
CMD ["rails", "server", "-b", "0.0.0.0"]
```

## Key Gems

| Gem | Purpose |
|-----|---------|
| devise | Authentication |
| pundit | Authorization |
| sidekiq | Background jobs |
| pg | PostgreSQL adapter |
| rspec-rails | Testing |
| factory_bot_rails | Test factories |
| rubocop-rails | Linting |
| tailwindcss-rails | Tailwind CSS integration |
| turbo-rails | Hotwire Turbo |
| stimulus-rails | Hotwire Stimulus |
