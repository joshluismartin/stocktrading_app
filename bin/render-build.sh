#!/usr/bin/env bash
# exit on error
set -o errexit

# Install dependencies
bundle install

# Precompile assets
bundle exec rails assets:precompile

# Run database migrations
bundle exec rails db:migrate

# Create admin user if it doesn't exist
bundle exec rails runner "
  unless User.exists?(email: 'admin@stockbit.com')
    admin = User.new(
      email: 'admin@stockbit.com',
      password: 'password123',
      password_confirmation: 'password123',
      name: 'Admin User',
      admin: true,
      status: 'approved',
      balance: 100000
    )
    admin.skip_confirmation!
    admin.save!
    puts 'Admin user created successfully'
  else
    puts 'Admin user already exists'
  end
"
