require 'spec_helper'

describe 'Chart App' do

  it "has section links for each metric key" do
    visit '/'

    expect(page).to have_link("Section 1")
    expect(page).to have_link("Section 2")
  end
end
