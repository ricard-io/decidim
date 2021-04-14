# frozen_string_literal: true

require "spec_helper"

describe "Vote online in an election inside a Voting", type: :system do
  let(:manifest_name) { "elections" }
  let(:questionnaire) { create(:questionnaire, :with_questions) }
  let!(:election) { create :election, :bb_test, :vote, component: component, questionnaire: questionnaire }
  let(:user) { create(:user, :confirmed, organization: component.organization) }
  let!(:datum) do
    create(:datum, :with_access_code, document_type: "DNI", document_number: "12345678X", birthdate: Date.civil(1980, 5, 11), postal_code: "04001", access_code: "1234")
  end
  let!(:elections) { create_list(:election, 2, :vote, component: component) } # prevents redirect to single election page
  let(:router) { Decidim::EngineRouter.main_proxy(component).decidim_voting_elections }

  include_context "with a component" do
    let(:voting) { create(:voting, :published, organization: organization) }
    let(:participatory_space) { voting }
    let(:organization_traits) { [:secure_context] }
  end

  include_context "with test bulletin board"

  before do
    election.reload # forces to reload the questions in the right order
    login_as(user, scope: :user) if user
  end

  describe "when the user is logged in" do
    it "can vote and then change the vote", :slow do
      vote_with_census_data

      page.find("a.focus__exit").click

      expect(page).to have_current_path router.election_path(id: election.id)
      expect(page).not_to have_content("You have already voted in this election.")

      click_link "Start voting"
    end
  end

  describe "when there is no user logged in" do
    let(:user) { nil }

    context "when questionnaire has questions" do
      it "can vote and sign up after feedback when questionnaire" do
        vote_with_census_data

        click_link "Give us some feedback"

        expect(page).to have_i18n_content(election.questionnaire.title, upcase: true)
        expect(page).to have_i18n_content(election.questionnaire.description)

        fill_in election.questionnaire.questions.first.body["en"], with: "My first answer"

        check "questionnaire_tos_agreement"

        accept_confirm do
          click_button "Submit"
        end

        expect(page).to have_content("New to Decidim?")

        within "#onboarding-modal" do
          click_button "No, thanks."
        end

        expect(page).to have_current_path router.election_path(id: election.id, onboarding: true)
      end
    end

    context "when questionnaire has no questions" do
      let!(:questionnaire) { create :questionnaire } # by default questionnaire doesn't have any questions

      it "can vote and sign up without feedback" do
        vote_with_census_data

        expect(page).to have_content("New to Decidim?")

        within "#onboarding-modal" do
          click_button "No, thanks."
        end

        click_link "Back to elections"

        expect(page).to have_current_path router.elections_path
      end
    end
  end

  context "when the voting is not published" do
    let(:election) { create :election, :upcoming, :complete, component: component }

    it_behaves_like "doesn't allow to vote"
    it_behaves_like "allows admins to preview the voting booth"
  end

  context "when the census data is not right" do
    it "can't vote", :slow do
      visit_component
      click_link translated(election.title)
      click_link "Start voting"

      within ".card__content" do
        select("DNI", from: "Document type")
        fill_in "Document number", with: "12345678X"
        fill_in "Postal code", with: "04001"
        fill_in "Day", with: "11"
        fill_in "Month", with: "05"
        fill_in "Year", with: "1980"
        fill_in "Access code", with: "1235"
        find("*[type=submit]").click
      end

      expect(page).to have_content("Document number")
      expect(page).to have_content("The given data doesn't match any voter.")
    end
  end

  def vote_with_census_data
    visit_component
    click_link translated(election.title)
    click_link "Start voting"

    within ".card__content" do
      select("DNI", from: "Document type")
      fill_in "Document number", with: "12345678X"
      fill_in "Postal code", with: "04001"
      fill_in "Day", with: "11"
      fill_in "Month", with: "05"
      fill_in "Year", with: "1980"
      fill_in "Access code", with: "1234"
      find("*[type=submit]").click
    end

    expect(page).not_to have_content("This is a preview of the voting booth.")

    uses_the_voting_booth
  end
end
