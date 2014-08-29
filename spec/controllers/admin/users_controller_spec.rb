require "spec_helper"

describe Admin::UsersController do
  let(:first_user) { FactoryGirl.create(:user, is_admin: true) }
  let(:_user) { FactoryGirl.create(:user) }

  before { sign_in first_user }

  describe "GET #index" do
    before { get :index }

    it "assigns @users" do
      expect(assigns(:users)).to eq([first_user])
    end

    it "renders the :index view" do
      expect(response).to render_template(:index)
    end
  end

  describe "GET #new" do
    before { get :new }

    it "assigns @user" do
      expect(assigns(:user)).to be_a_new(User)
    end

    it "renders the :new view" do
      expect(response).to render_template(:new)
    end
  end

  describe "GET #show" do
    before { get :show, :id => first_user.id }

    it "assigns @user" do
      expect(assigns(:user)).to eq(first_user)
    end

    it "renders the :show view" do
      expect(response).to render_template(:show)
    end
  end

  describe "GET #edit" do
    before { get :edit, :id => first_user.id }

    it "assigns @user" do
      expect(assigns(:user)).to eq(first_user)
    end

    it "renders the :edit view" do
      expect(response).to render_template(:edit)
    end
  end

  describe "POST #create" do
    context "when valid" do
      before { post :create, :user => { :login => "Username", :email => "email@example.com"  } }

      it "will redirect to admin_user path" do
        expect(response).to be_successful
      end

      pending "will set flash[:success]" do
        expect(flash[:success]).to be_present
      end
    end

    context "when invalid" do
      before { post :create, :user => { :login => "", :email => "" } }

      it "will render :new view" do
        expect(response).to render_template(:new)
      end

      it "will set flash[:error]" do
        expect(flash[:error]).to be_present
      end
    end
  end

  describe "PUT #update" do
    context "when success" do
      before { put :update, :user => { :login => "updated", :email => "email@updated.com" } }

      pending "will set flash[:success]" do
        expect(flash[:success]).to be_present
      end
    end
  end

  describe "DELETE #destroy" do
    before { delete :update, :id => _user.id }

    pending "will redirect to admin_users_path" do
      expect(response).to redirect_to admin_users_path
    end

    pending "will set flash[:success]" do
      expect(flash[:success]).to be_present
    end
  end

  pending "change_roles" do
  end

  pending "manage_roles" do
  end

  ## private ##

  pending "sort_column" do
  end

  pending "user_params" do
  end

  pending "toggle_attribute!" do
  end
end