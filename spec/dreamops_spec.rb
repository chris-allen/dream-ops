require 'dream-ops'

module DreamOps
  describe ".formatter" do
    context "with default formatter" do
      it "is human readable" do
        expect(DreamOps.formatter).to be_an_instance_of(HumanFormatter)
      end
    end
  end
end
