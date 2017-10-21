require 'spec_base.rb'

describe Ragios::Web::Admin do
  before(:each) do
    @admin = Ragios::Web::Admin.new
  end

  describe "#authenticate?" do
    context "when correct credentials are provided" do
      it "returns true" do
        authenticated = @admin.authenticate?(Ragios::ADMIN[:username], Ragios::ADMIN[:password])
        expect(authenticated).to be_truthy
      end
    end

    context "when incorrect credentials are provided" do
      it "returns false" do
        authenticated = @admin.authenticate?("incorrect", "incorrect")
        expect(authenticated).to be_falsey
      end
    end
  end

  describe "#valid_token?" do
    context "authentication is enabled" do
      before(:each) do
        allow(@admin).to receive(:authentication).and_return(true)
      end

      context "when a valid token is provided" do
        it "returns true" do
          token = @admin.session
          is_valid = @admin.valid_token?(token)
          expect(is_valid).to be_truthy
        end
      end

      context "when the provided token is invalid" do
        it "returns false" do
          invalid_token = SecureRandom.uuid
          is_valid = @admin.valid_token?(invalid_token)
          expect(is_valid).to be_falsey
        end
      end

      context "when token is blank" do
        it "returns false" do
          blank_token = ""
          is_valid = @admin.valid_token?(blank_token)
          expect(is_valid).to be_falsey
        end
      end
    end

    context "authentication is disabled" do
      before(:each) do
        allow(@admin).to receive(:authentication).and_return(false)
      end

      context "when a valid token is provided" do
        it "returns true" do
          token = @admin.session
          is_valid = @admin.valid_token?(token)
          expect(is_valid).to be_truthy
        end
      end

      context "when the provided token is invalid" do
        it "returns true" do
          invalid_token = SecureRandom.uuid
          is_valid = @admin.valid_token?(invalid_token)
          expect(is_valid).to be_truthy
        end
      end
    end
  end

  describe "#invalidate_token" do
    context "when token is blank" do
      it "returns false" do
        blank_token = ""
        expect(@admin.invalidate_token(blank_token)).to be_falsey
      end
    end

    context "when token is found" do
      it "returns true and deletes the token" do
        token = @admin.session
        expect(@admin.invalidate_token(token)).to include(ok: true)
      end
    end

    context "when token is not found" do
      it "returns false" do
        invalid_token = SecureRandom.uuid
        expect(@admin.invalidate_token(invalid_token)).to be_falsey
      end
    end
  end

  describe "#session" do
    it "returns a session token and stores it in the database" do
      token = @admin.session
      result = Ragios.database.get_doc(token)
      expect(result).to include(_id: token)
    end
  end
end

