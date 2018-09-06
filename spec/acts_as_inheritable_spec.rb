require 'spec_helper'
require 'support/migrations'
require 'support/factories'
require 'support/models'

RSpec.describe "ActiveRecord::Base model with #acts_as_inheritable" do

  describe 'describe `acts_as_inheritable` setup' do
    context 'when `acts_as_inheritable` is defined without options' do
      it 'raises an `ArgumentError`' do
        expect{
          class Person < ActiveRecord::Base
            acts_as_inheritable
          end
        }.to raise_error(ArgumentError)
      end
    end
    context 'when `acts_as_inheritable` is defined with empty options' do
      it 'raises an `ArgumentError`' do
        expect{
          class Person < ActiveRecord::Base
            acts_as_inheritable{attributes:[],associations:[]}
          end
        }.to raise_error(ArgumentError)
      end
    end
  end

  describe '#apply_attributes_to_parent' do
    let(:person){ create(:person, :with_nil_parent, favorite_color: 'chartreuse', last_name: 'Parker', soccer_team: 'Sharks') }
    let!(:person_parent) { person.parent }
    it 'applies values from child to parent' do
      person.apply_attributes_to_parent
      expect(person_parent.favorite_color).to eq person.favorite_color
      expect(person_parent.last_name).to eq person.last_name
      expect(person_parent.soccer_team).to eq person.soccer_team
    end
    context 'when `force` is set to true' do
      let!(:person_parent) { create(:person, favorite_color: nil, last_name: 'Camilla', soccer_team: 'verdolaga') }
      let(:person){ create(:person, parent: person_parent, favorite_color: 'Baby Blue', last_name: 'Shamwow', soccer_team: 'Tigers') }

      it 'applies values from child to parent even if those attributes have a value' do
        person.apply_attributes_to_parent true
        expect(person_parent.favorite_color).to eq person.favorite_color
        expect(person_parent.last_name).to eq person.last_name
        expect(person_parent.soccer_team).to eq person.soccer_team
      end

      context 'and `not_force_for` has attributes' do
        it 'applies values from child to parent even if those attributes have a value but exclude then ones on `not_force_for`' do
          person.apply_attributes_to_parent true, ['soccer_team']
          expect(person_parent.favorite_color).to eq person.favorite_color
          expect(person_parent.last_name).to eq person.last_name
          expect(person_parent.soccer_team).to eq 'verdolaga'
        end
      end
    end

    context 'when `method_to_update` is used and applying child attributes to parent' do
      let(:person){ create(:person, :with_nil_parent, favorite_color: "black", last_name: "Jameson", soccer_team: "Ninjas") }
      let!(:person_parent) { person.parent }

      context 'when `method_to_update` is `update_attributes`' do
        it 'passes values from child record and saves the parent' do
          person.apply_attributes_to_parent false, [], 'update_attributes'
          person.reload
          expect(person_parent.favorite_color).to eq person.favorite_color
          expect(person_parent.last_name).to eq person.last_name
          expect(person_parent.soccer_team).to eq person.soccer_team
        end
      end
      context 'when `method_to_update` is `update_columns`' do
        it 'passes values from child record and saves the parent' do
          person.apply_attributes_to_parent false, [], 'update_columns'
          person.reload
          expect(person_parent.favorite_color).to eq person.favorite_color
          expect(person_parent.last_name).to eq person.last_name
          expect(person_parent.soccer_team).to eq person.soccer_team
        end
      end
    end
  end


  describe '#inherit_attributes' do
    let(:person){ create(:person, :with_parent, favorite_color: nil, last_name: nil, soccer_team: nil) }
    let!(:person_parent) { person.parent }
    it 'inherits values from his parent' do
      person.inherit_attributes
      expect(person.favorite_color).to eq person_parent.favorite_color
      expect(person.last_name).to eq person_parent.last_name
      expect(person.soccer_team).to eq person_parent.soccer_team
    end
    context 'when `force` is set to true' do
      let(:person){ create(:person, :with_parent, favorite_color: nil, last_name: 'r3d3 restrepo', soccer_team: 'verdolaga') }
      let!(:person_parent) { person.parent }
      it 'inherits values from his parent even if those attributes have a value' do
        person.inherit_attributes true
        expect(person.favorite_color).to eq person_parent.favorite_color
        expect(person.last_name).to eq person_parent.last_name
        expect(person.soccer_team).to eq person_parent.soccer_team
      end
      context 'and `not_force_for` has attributes' do
        it 'inherits values from his parent even if those attributes have a value but exclude then ones on `not_force_for`' do
          person.inherit_attributes true, ['soccer_team']
          expect(person.favorite_color).to eq person_parent.favorite_color
          expect(person.last_name).to eq person_parent.last_name
          expect(person.soccer_team).to eq 'verdolaga'
        end
      end
    end
    context 'when `method_to_update` is used and inheriting from parent' do
      let(:person){ create(:person, :with_parent, favorite_color: nil, last_name: nil, soccer_team: nil) }
      let!(:person_parent) { person.parent }
      context 'when `method_to_update` is `update_attributes`' do
        it 'inherits values from his parent and saves the record' do
          person.inherit_attributes false, [], 'update_attributes'
          person.reload
          expect(person.favorite_color).to eq person_parent.favorite_color
          expect(person.last_name).to eq person_parent.last_name
          expect(person.soccer_team).to eq person_parent.soccer_team
        end
      end
      context 'when `method_to_update` is `update_columns`' do
        it 'inherits values from his parent and saves the record' do
          person.inherit_attributes false, [], 'update_columns'
          person.reload
          expect(person.favorite_color).to eq person_parent.favorite_color
          expect(person.last_name).to eq person_parent.last_name
          expect(person.soccer_team).to eq person_parent.soccer_team
        end
      end
    end
  end

  describe '#inherit_relations' do
     describe '`has_one` associations' do
       let(:person_parent) { create(:person, :with_pet) }
       let!(:person){ create(:person, parent: person_parent) }

       it 're-creates the pet from the parent' do
         expect {
           person.inherit_relations
         }.to change(Pet, :count).by(1)
         expect(person.pet.id).to_not eq person_parent.pet.id
       end
     end
  	 describe '`belongs_to` associations' do
	     let(:person_parent) { create(:person, :with_clan) }
	     let!(:person){ create(:person, parent: person_parent) }

	     it 're-creates the clan from the parent' do
	       expect {
	         person.inherit_relations
	       }.to change(Clan, :count).by(1)
	       expect(person.clan.id).to_not eq person_parent.clan.id
	     end
  	 end
  	describe '`has_many` associations' do

	    let(:person_parent) { create(:person, :with_shoes, number_of_shoes: 2) }
	    let!(:person){ create(:person, parent: person_parent) }

	    it 're-creates all the shoes from the parent' do
	      expect {
	        person.inherit_relations
	      }.to change(Shoe, :count).by(person_parent.shoes.count)
	    end

       	context 'when association is polymorphic' do
           let(:person_parent) { create(:person, :with_pictures, number_of_pictures: 2) }
           let!(:person){ create(:person, parent: person_parent) }

           it 're-creates all the pictures from the parent' do
             expect {
               person.inherit_relations
             }.to change(Picture, :count).by(person_parent.pictures.count)
           end
       	end

       	context 'when association uses a different name' do
           let(:person_parent) { create(:person, :with_toys, number_of_toys: 2) }
           let!(:person){ create(:person, parent: person_parent) }

           it 're-creates all the toys from the parent' do
             expect {
               person.inherit_relations
             }.to change(Toy, :count).by(person_parent.toys.count)
           end
       	end
  	 end
  end


  describe '#apply_relations_to_parent' do
     describe '`has_one` associations' do
       let(:person_parent){ create(:person) }
       let!(:person) { create(:person, :with_pet, parent: person_parent) }

       it 're-creates the parent pet from the child pet' do
        expect {
          person.apply_relations_to_parent
        }.to change(Pet, :count).by(1)
        expect(person_parent.pet.id).to_not eq person.pet.id
       end
     end

     describe '`belongs_to` associations' do
       let(:person_parent) { create(:person) }
       let!(:person){ create(:person, :with_clan, parent: person_parent) }

       it 're-creates the parent clan from the child clan' do
         expect {
           person.apply_relations_to_parent
         }.to change(Clan, :count).by(1)
         expect(person_parent.clan.id).to_not eq person.clan.id
       end
     end

    describe '`has_many` associations with several levels of depth' do
      let(:person_parent) { create(:person) }
      let!(:person){ create(:person, :with_shoes_and_socks, number_of_shoes: 2, parent: person_parent) }

      it 're-creates all the parent shoes from the child shoes' do
        expect(person.shoes.first.socks.count).to eq(2)
        expect {
          person.apply_relations_to_parent
        }.to change(Shoe, :count).by(person.shoes.count)
        expect(person_parent.shoes.first.socks.count).to eq(2)
      end
    end


   describe '`has_many` associations' do

     let(:person_parent) { create(:person) }
     let!(:person){ create(:person, :with_shoes, number_of_shoes: 2, parent: person_parent) }

     it 're-creates all the parent shoes from the child shoes' do
       expect {
         person.apply_relations_to_parent
       }.to change(Shoe, :count).by(person.shoes.count)
     end

     context 'when association is polymorphic' do
       let(:person_parent) { create(:person) }
       let!(:person){ create(:person, :with_pictures, number_of_pictures: 2, parent: person_parent) }

       it 're-creates all the parent pictures from the child pictures' do
         expect {
           person.apply_relations_to_parent
         }.to change(Picture, :count).by(person.pictures.count)
       end
     end

     context 'when association uses a different name' do
       let(:person_parent) { create(:person) }
       let!(:person){ create(:person, :with_toys, number_of_toys: 2, parent: person_parent) }

       it 're-creates all the parent toys from the child toys' do
         expect {
           person.apply_relations_to_parent
         }.to change(Toy, :count).by(person.toys.count)
       end
     end
   end
  end
end