# frozen_string_literal: true

class User < ApplicationRecord
  has_secure_password

  validates :email, presence: true, uniqueness: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, presence: true
  validate :password_minimum_strength_requirements

  MINIMUM_PASSWORD_LENGTH = 14
  MAXIMUM_PASSWORD_LENGTH = 60

  def password_minimum_strength_requirements # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    forbidden_words = email.split('@').map(&:downcase) + %w[
      qwerty welcome password changeme iloveyou abc 123 1q2w3e4r zaq12wsx
      dragon sunshine princess letmein monkey superman asdfghjkl
    ]

    return if [
      forbidden_words.each_with_object(password.downcase).none? { |word, dcp| word.in?(dcp) },

      password.length >= MINIMUM_PASSWORD_LENGTH,
      password.length <= MAXIMUM_PASSWORD_LENGTH,

      password =~ /(?=.*?[A-Z])(?=.*?[a-z])(?=.*?[0-9])(?=.*?[#`~|?!@$%^&*:;()\-_., +=\[\]{}'"])/,
      password !~ /((.)\2{2,})/
    ].all?

    errors.add :password, %(must be strong and contains at least 14 characters
      with 1 lowercase letter, 1 uppercase letter, 1 special character
      (<a href="https://www.owasp.org/index.php/Password_special_characters" target="_blank">character list</a>),
      a number, and no more than two identical characters in a row.).squish
  end
end
