FactoryGirl.define do
  factory :event do
    title { Faker::Lorem.sentence }

    category { Fake::Event.category }

    ambiance { Fake::Event.ambiance }

    level { Fake::Event.level }

    capacity { Faker::Number.between(1, 999) }

    short_description { Faker::Lorem.sentences(2) }

    description { Faker::Lorem.paragraph }

    begin_at { Faker::Time.between(Time.now, Time.now + 10.day, :all) }

    end_at { Faker::Time.between(Time.now + 10.day, Time.now + 20.day, :all) }

    type :normal

    street   { Faker::Address.street_address }
    postcode { Faker::Address.postcode       }
    city     { Faker::Address.country        }
    state    { Faker::Address.state          }
    country  { Faker::Address.country        }

    auto_accept false

    private { Faker::Boolean.boolean }

    association :host, factory: :profile_verified

    before(:create) do |event|
      unless event.unlimited_capacity?
        event.min_capacity = 0
      end
    end

    trait :auto_accept do
      auto_accept true
    end

    trait :unlimited_access do
      min_capacity 0

      capacity nil

      unlimited_capacity true
    end

    trait :flexible do
      begin_at nil

      end_at nil

      type :flexible

      new_time_slots { Fake::Event.time_slots }
    end

    trait :recurrent do
      begin_at nil

      end_at nil

      type :recurrent

      new_time_slots { Fake::Event.time_slots }
    end

    trait :of_recurrent do
      association :parent, factory: [:event, :recurrent]
    end

    factory :event_with_time_slots_members, traits: [:flexible] do
      after(:create) do |event|
        event.time_slots.each do |time_slot|
          members_count = Faker::Number.between(1, 1)

          create_list(:time_slot_submission, members_count, time_slot: time_slot)
        end
      end
    end

    factory :event_confirmable, traits: [:flexible] do
      after(:create) do |event|
        event.time_slots << TimeSlot.new(created_at: 2.days.ago, begin_at: Time.now + 2.hours)
      end
    end

    trait :with_comments do
      transient { comments_count 10 }

      after(:create) do |event, evaluator|
        create_list(:comment, evaluator.comments_count / 2, resource: event)
        create_list(:comment, evaluator.comments_count / 2, :private, resource: event)
      end
    end

    trait :with_pending_submissions do
      transient { pendings_count 5 }

      after(:create) do |event, evaluator|
        create_list(:submission, evaluator.pendings_count, :pending, event: event)
      end
    end

    factory :event_closed do
      begin_at { Faker::Time.backward(5, :all) }

      to_create do |event|
        event.save(validate: false)
      end
    end

    factory :event_reached_time_slot_min, traits: [:flexible] do
      new_time_slots { Fake::Event.time_slots[0..1] }
    end

    factory :event_with_submissions do
      transient do
        submissions_count 10

        capacity 15
      end

      before(:create) do |event, evaluator|
        if evaluator.capacity <= evaluator.submissions_count
          event.capacity = evaluator.submissions_count + Faker::Number.between(1, 5)
        else
          event.capacity = evaluator.capacity
        end
      end

      after(:create) do |event, evaluator|
        create_list(:submission, evaluator.submissions_count, event: event)
      end
    end

    factory :event_with_attendees do
      transient { attendees_count 10 }

      before(:create) do |event, evaluator|
        event.capacity = evaluator.attendees_count * 2
      end

      after(:create) do |event, evaluator|
        create_list(:submission, evaluator.attendees_count, :confirmed, event: event)
      end

      trait :ready do
        after(:create) do |event|
          event.update(min_capacity: event.attendees_count - 1)
        end
      end

      trait :just_ready do
        after(:create) do |event|
          event.update(min_capacity: event.attendees_count)
        end
      end

      trait :not_ready do
        after(:create) do |event|
          event.update(min_capacity: event.attendees_count + 2)
        end
      end

      trait :almost_ready do
        after(:create) do |event|
          event.update(min_capacity: event.attendees_count + 1)
        end
      end

      factory :event_with_one_slot_remaining do
        after(:create) do |event, evaluator|
          event.update(capacity: evaluator.attendees_count + 1)
        end
      end

      factory :event_full do
        after(:create) do |event, evaluator|
          event.capacity = evaluator.attendees_count
          event.save(validate: false)
        end
      end
    end

    after(:build) do |event|
      GeoLocation.register(event)
    end
  end
end
