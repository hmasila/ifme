# frozen_string_literal: true

RSpec.describe MeetingsController, type: :controller do
  describe 'without being logged in' do
    subject { controller }
    # TODO: implement session controller
    # it_behaves_like 'LoggedOut'
    describe 'GET' do
      %w[join leave].each do |action|
        it "#{action} redirects to login" do
          get action
          expect(response).to redirect_to('/users/sign_in')
        end
      end
    end

    describe 'GET #show' do
      let!(:meeting) { create(:meeting) }
      let(:user) { create(:user) }
      let!(:meeting_member) do
        create(:meeting_member, user: user, meeting: meeting)
      end

      context 'when user is logged in' do
        before { sign_in user }

        context 'included in the meeting' do
          context 'as member' do
            before { get :show, params: { id: meeting.id } }

            it { expect(response).to have_http_status(:ok) }
            it { expect(response).to render_template(:show) }
          end

          context 'as leader' do
            before do
              meeting_member.update(leader: true)
              get :show, params: { id: meeting.id }
            end

            it { expect(response).to have_http_status(:ok) }
            it { expect(response).to render_template(:show) }
          end
        end

        context 'not included in the meeting' do
          before do
            meeting_member.destroy
            get :show, params: { id: meeting.id }
          end

          it { expect(response).to have_http_status(:redirect) }
          it { expect(response).to redirect_to(groups_path) }
        end

        context 'inexistent meeting id' do
          before { get :show, params: { id: 111 } }

          it { expect(response).to have_http_status(:redirect) }
          it { expect(response).to redirect_to(groups_path) }
        end
      end

      context 'when user is logged out' do
        before { get :show, params: { id: meeting.id } }

        it_behaves_like :with_no_logged_in_user
      end
    end
  end

  describe 'GET #new' do
    let!(:user) { create(:user) }
    let!(:group_member) do
      create(:group_member, id: 1, user: user, leader: true)
    end

    context 'when the user is not logged in' do
      before do
        get :new, params: { group_id: group_member.group_id }
      end

      it { expect(response).to redirect_to new_user_session_path }
    end

    context 'when the user is logged in' do
      include_context :logged_in_user

      context 'user is the group leader' do
        before do
          get :new, params: { group_id: group_member.group_id }
        end

        it { expect(response).to have_http_status(:ok) }
      end

      context 'user is not the leader' do
        before do
          group_member.update!(leader: false)
          get :new, params: { group_id: group_member.group_id }
        end

        it { expect(response).to redirect_to group_path(group_member.group_id) }
      end
    end
  end

  describe 'GET #edit' do
    let!(:user) { create(:user, id: 1) }
    let(:meeting) { create(:meeting, id: 1) }
    let!(:group_member) { create(:group_member, group_id: meeting.group_id, id: 1, user: user, leader: true) }
    let(:meeting_member) { create(:meeting_member, user: user, meeting: meeting) }

    context 'when the user is not logged in' do
      before do
        get :edit, params: { id: meeting.id }
      end

      it_behaves_like :with_no_logged_in_user
    end

    context 'when the user is logged in' do
      include_context :logged_in_user

      context 'user is the group leader' do
        before do
          get :edit, params: { id: meeting.id }
        end
        it { expect(response).to have_http_status(:ok) }
      end

      context 'user is not the group leader' do
        before do
          group_member.update!(leader: false)
          get :edit, params: { id: meeting.id }
        end

        it { expect(response).to redirect_to group_path(group_member.group_id) }
      end
    end
  end

  describe 'POST #create' do
    let!(:user) { create(:user) }
    let!(:group) { create(:group) }
    let!(:group_member) do
      create(:group_member, id: 1, user: user, group: group, leader: true)
    end
    let(:valid_meeting_params) { attributes_for(:meeting).merge(group_id: group.id) }
    let(:invalid_meeting_params) { { name: nil, description: nil, group_id: group.id } }

    context 'when the user is not logged in' do
      before do
        post :create, params: { meeting: valid_meeting_params }
      end

      it { expect(response).to redirect_to new_user_session_path }
    end

    context 'when the user is logged in' do
      include_context :logged_in_user

      context 'when params are invalid' do
        before do
          post :create, params: { meeting: invalid_meeting_params }
        end
        
        it { expect(response).to render_template(:new) }
      end

      context 'when params are valid' do
        context 'user is the group leader' do
          it 'creates a new meeting' do
            expect { post :create, params: { meeting: valid_meeting_params }}
              .to change(Meeting, :count).by 1
          end

          it 'creates a new meeting_member' do
            expect { post :create, params: { meeting: valid_meeting_params }}
              .to change(MeetingMember, :count).by 1
          end

          it 'redirects to group path' do
            post :create, params: { meeting: valid_meeting_params }
            expect(response).to redirect_to group_path(group.id)
          end
        end

        context 'user is not the leader' do
          before do
            group_member.update!(leader: false)
            post :create, params: { meeting: valid_meeting_params }
          end

          it { expect(response).to redirect_to group_path(group.id) }
        end
      end
    end
  end

  describe 'PATCH/PUT #update' do
    let(:meeting) { create(:meeting) }
    let!(:user) { create(:user) }
    let(:valid_update_params) { attributes_for(:meeting).merge(name: 'updated name') }
    let(:invalid_update_params) { { name: nil, description: nil } }

    context 'when the user is logged in' do
      include_context :logged_in_user
      context 'when valid params are supplied' do
        before do
          allow(Meeting).to receive_message_chain(:friendly, :find).and_return(meeting)
        end

        it 'updates the meeting' do
          expect(meeting).to receive(:update).with(double(valid_update_params))
          patch :update, params: { id: meeting.id, meeting: valid_update_params }
        end
        it 'redirects to the meeting page' do
          patch :update, params: { id: meeting.id, meeting: valid_update_params }
          expect(response).to redirect_to meeting_path(meeting.reload.slug)
        end
      end
      
      context 'when invalid params are supplied' do
        it 're-renders the edit form' do
          patch :update, params: { id: meeting.id, meeting: invalid_update_params }
          expect(response).to render_template(:edit)
        end
      end
    end
    
    context 'when the user is not logged in' do
      before { patch :update, params: { id: meeting.id } }
      it_behaves_like :with_no_logged_in_user
    end
  end

  describe 'DELETE #destroy' do
    let(:user) { create(:user) }
    let(:group) { create(:group) }
    let(:meeting) { create(:meeting, group_id: group.id) }
    let!(:group_member) { create(:group_member, group_id: meeting.group_id, user: user, leader: true) }
    let(:meeting_member) { create(:meeting_member, user: user, meeting: meeting) }

    context 'when the user is logged in' do
      include_context :logged_in_user
      
      context 'user is the group leader' do
        before do
          allow(Meeting).to receive_message_chain(:friendly, :find).and_return(meeting)
        end

        it 'deletes the meeting and meeting members' do
          expect(meeting.meeting_members).to receive(:destroy_all)
          expect(meeting).to receive(:destroy)
          delete :destroy, params: { id: meeting.id }
        end

        it 'redirects to the group path page' do
          delete :destroy, params: { id: meeting.id }
          expect(response).to redirect_to group_path(group.id)
        end
      end

      context 'user is not the leader' do
        before do
          group_member.update!(leader: false)
          delete :destroy, params: { id: meeting.id }
        end

        it { expect(response).to redirect_to group_path(group.id) }
      end
    end
    context 'when the user is not logged in' do
      before { delete :destroy, params: { id: meeting.id } }
      it_behaves_like :with_no_logged_in_user
    end
  end
end
