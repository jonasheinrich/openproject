#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2013 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

require File.expand_path('../../../../spec_helper', __FILE__)

describe Api::V2::ReportingsController do
  let(:current_user) { FactoryGirl.create(:admin) }

  before do
    User.stub(:current).and_return current_user
  end

  describe 'index.xml' do
    describe 'w/o a given project' do
      it 'renders a 404 Not Found page' do
        get 'index', :format => 'xml'

        response.response_code.should == 404
      end
    end

    describe 'w/ an unknown project' do
      it 'renders a 404 Not Found page' do
        get 'index', :project_id => '4711', :format => 'xml'

        response.response_code.should == 404
      end
    end

    describe 'w/ a known project' do
      let(:project) { FactoryGirl.create(:project, :identifier => 'test_project') }

      def fetch
        get 'index', :project_id => project.identifier, :format => 'xml'
      end
      let(:permission) { :view_reportings }
      it_should_behave_like "a controller action which needs project permissions"

      describe 'w/o any reportings within the project' do
        it 'assigns an empty reportings array' do
          get 'index', :project_id => project.identifier, :format => 'xml'
          assigns(:reportings).should == []
        end

        it 'renders the index builder template' do
          get 'index', :project_id => project.identifier, :format => 'xml'
          response.should render_template('api/v2/reportings/index', :formats => ["api"])
        end
      end

      describe 'w/ 3 reportings within the project' do
        before do
          @created_reportings = [
            FactoryGirl.create(:reporting, :project_id => project.id),
            FactoryGirl.create(:reporting, :project_id => project.id),
            FactoryGirl.create(:reporting, :reporting_to_project_id => project.id)
          ]
        end

        it 'assigns a reportings array containing all three elements' do
          get 'index', :project_id => project.identifier, :format => 'xml'
          assigns(:reportings).should =~ @created_reportings
        end

        it 'renders the index builder template' do
          get 'index', :project_id => project.identifier, :format => 'xml'
          response.should render_template('api/v2/reportings/index', :formats => ["api"])
        end

        describe 'w/ ?only=via_source' do
          it 'assigns a reportings array containg the two reportings where project.id is source' do
            get 'index', :project_id => project.identifier, :format => 'xml', :only => 'via_source'
            assigns(:reportings).should =~ @created_reportings[0..1]
          end
        end

        describe 'w/ ?only=via_target' do
          it 'assigns a reportings array containg the two reportings where project.id is source' do
            get 'index', :project_id => project.identifier, :format => 'xml', :only => 'via_target'
            assigns(:reportings).should == @created_reportings[2..2]
          end
        end
      end
    end
  end

  describe 'show.xml' do
    describe 'w/o a valid reporting id' do
      describe 'w/o a given project' do
        it 'renders a 404 Not Found page' do
          get 'show', :id => '4711', :format => 'xml'

          response.response_code.should == 404
        end
      end

      describe 'w/ an unknown project' do
        it 'renders a 404 Not Found page' do
          get 'index', :project_id => '4711', :id => '1337', :format => 'xml'

          response.response_code.should == 404
        end
      end

      describe 'w/ a known project' do
        let(:project) { FactoryGirl.create(:project, :identifier => 'test_project') }

        it 'raises ActiveRecord::RecordNotFound errors' do
          lambda do
            get 'show', :project_id => project.id, :id => '1337', :format => 'xml'
          end.should raise_error(ActiveRecord::RecordNotFound)
        end
      end
    end

    describe 'w/ a valid reporting id' do
      let(:project) { FactoryGirl.create(:project, :identifier => 'test_project') }
      let(:reporting) { FactoryGirl.create(:reporting, :project_id => project.id) }

      describe 'w/o a given project' do
        it 'renders a 404 Not Found page' do
          get 'show', :id => reporting.id, :format => 'xml'

          response.response_code.should == 404
        end
      end

      describe 'w/ a known project' do
        def fetch
          get 'show', :project_id => project.id, :id => reporting.id, :format => 'xml'
        end
        let(:permission) { :view_reportings }
        it_should_behave_like "a controller action which needs project permissions"

        it 'assigns the reporting' do
          get 'show', :project_id => project.id, :id => reporting.id, :format => 'xml'
          assigns(:reporting).should == reporting
        end

        it 'renders the index builder template' do
          get 'index', :project_id => project.id, :id => reporting.id, :format => 'xml'
          response.should render_template('api/v2/reportings/index', :formats => ["api"])
        end
      end
    end
  end
end
