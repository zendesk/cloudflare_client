FactoryBot.define do
    factory :values, class: Hash do
        skip_create
        initialize_with(&FactoryHelper.initializer)

        factory :value_write do
            success { true }
            errors { [] }
            messages { [] }
        end

        factory :value_delete do
            success { true }
            errors { [] }
            messages { [] }
        end
    end    
end