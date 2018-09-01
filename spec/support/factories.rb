require 'faker'

FactoryGirl.define do
  factory :person do
    first_name              { Faker::Name.first_name }
    favorite_color    { Faker::Commerce.color }
    last_name         { Faker::Name.last_name }
    soccer_team       { Faker::App.name }

    trait :with_parent do
      parent { create(:person) }
    end

    trait :with_nil_parent do
      parent { create(:person, favorite_color: nil, last_name: nil, soccer_team: nil) }
    end

    trait :with_clan do
      clan { create(:clan) }
    end

    trait :with_pet do
      pet { create(:pet) }
    end

    trait :with_toys do
      transient do
        number_of_toys 4
      end
      after :create do |person, evaluator|
        create_list :toy, evaluator.number_of_toys, owner: person
      end
    end

    trait :with_shoes do
      transient do
        number_of_shoes 4
      end
      after :create do |person, evaluator|
        create_list :shoe, evaluator.number_of_shoes, person: person
      end
    end

     trait :with_shoes_and_socks do
      transient do
        number_of_shoes 4
      end
      after :create do |person, evaluator|
        create_list :shoe,  evaluator.number_of_shoes, :with_socks, person: person
      end
    end

    trait :with_pictures do
      transient do
        number_of_pictures 4
      end
      after :create do |person, evaluator|
        create_list :picture, evaluator.number_of_pictures, imageable: person
      end
    end
  end

  factory :clan do
    name     { Faker::Lorem.word }
  end

  factory :pet do
    name     { Faker::Lorem.word }
    breed     { Faker::Lorem.word }
  end

  factory :picture do
    url      { Faker::Internet.url }
    place    { Faker::Address.city }
  end

  factory :sock do
    name {Faker::Lorem.word }
  end

  factory :toy do
    friendly    { [true, false].sample}
    material    { Faker::Lorem.word }
    color       { Faker::Commerce.color }
    brand       { Faker::Company.name }
  end

  factory :shoe do
    sneakers    { [true, false].sample}
    size       	{ Faker::Number.number(3) }
    brand       { Faker::Company.name }

    trait :with_socks do
      socks { create_list(:sock, 2) }
    end
  end
end