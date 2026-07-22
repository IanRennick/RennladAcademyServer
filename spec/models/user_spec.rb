# spec/models/user_spec.rb
# =========================================================================
# SYSTEM USER ACCOUNT MODEL MATRIX SPEC
# - Stress-tests unique handle validations and case-insensitive collision guards
# - Verifies dual credentials logic handling usernames and emails interchangeably
# =========================================================================
require "rails_helper"

RSpec.describe "User Model Identity Matrix", type: :model do
  # --- Setup Shared Test Matrix Variables ---
  let!(:admin) { User.create!(username: "master_admin", email: "admin@test.com", password: "password123", role: :admin) }

  # =========================================================================
  # 1. DATA INTEGRITY SHIELD TESTS
  # =========================================================================
  describe "Data Integrity Guard Shields" do
    it "safely creates user accounts with standard roles and default offline statuses" do
      student = User.create!(username: "new_student", email: "student@test.com", password: "password123", role: :student)

      expect(student.role).to eq("student")
      expect(student.status).to eq("offline")
      expect(student.avatar_initial).to eq("N")
    end

    it "blocks account creations with invalid emails or spaced username handles" do
      bad_user = User.new(username: "bad student", email: "corrupt_mail", password: "password123")
      expect(bad_user).not_to be_valid
    end

    it "enforces strict uniqueness barriers across both usernames and emails case-insensitively" do
      User.create!(username: "duplicate_me", email: "unique@test.com", password: "password123")

      collision = User.new(username: "DUPLICATE_ME", email: "another@test.com", password: "password123")
      expect(collision).not_to be_valid
    end
  end

  # =========================================================================
  # 2. DUAL CREDENTIALS INTERCHANGEABLE AUTHENTICATION GATES TEST
  # =========================================================================
  describe ".authenticate (Dual Credentials Gate)" do
    let!(:auth_user) { User.create!(username: "login_test", email: "logintest@test.com", password: "securepassword", role: :student) }

    it "resolves and log-ins accounts using either their username handle or email interchangeably" do
      expect(User.authenticate("login_test", "securepassword")).to eq(auth_user)
      expect(User.authenticate("logintest@test.com", "securepassword")).to eq(auth_user)
    end

    it "returns nil when passwords or credential text fields fail validation checks" do
      expect(User.authenticate("login_test", "wrongpassword")).to eq(nil)
      expect(User.authenticate("unknown_user", "securepassword")).to eq(nil)
    end
  end
end
