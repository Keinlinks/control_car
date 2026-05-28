require "test_helper"

class ImageTest < ActiveSupport::TestCase
  test "belongs to a work order" do
    association = Image.reflect_on_association(:work_order)

    assert_not_nil association
    assert_equal :belongs_to, association.macro
    assert_equal WorkOrder, association.klass
  end

  test "requires storage_path" do
    validators = Image.validators_on(:storage_path)

    assert validators.any? { |validator| validator.is_a?(ActiveModel::Validations::PresenceValidator) }
  end

  test "inherits from entity record" do
    assert_equal EntityRecord, Image.superclass
  end
end
