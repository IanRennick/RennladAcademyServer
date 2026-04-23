require "application_system_test_case"

class WritingsTest < ApplicationSystemTestCase
  setup do
    @writing = writings(:one)
  end

  test "visiting the index" do
    visit writings_url
    assert_selector "h1", text: "Writings"
  end

  test "should update Writing" do
    visit writing_url(@writing)
    click_on "Edit this writing", match: :first

    fill_in "Body", with: @writing.body
    click_on "Update Writing"

    assert_text "Writing was successfully updated"
    click_on "Back"
  end

  test "should destroy Writing" do
    visit writing_url(@writing)
    click_on "Destroy this writing", match: :first

    assert_text "Writing was successfully destroyed"
  end
end
