require 'dream-ops'
require 'dream-ops/utils/threaded_enum'

module DreamOps
  describe ".formatter" do
    context "with default formatter" do
      it "is human readable" do
        expect(DreamOps.formatter).to be_an_instance_of(HumanFormatter)
      end
    end
  end

  describe "threaded enum" do
    before(:example) do
      @enum = ThreadedEnum.new do |y|
        y << 1
        y << 2
        y << 3
      end
    end

    context "with simple enum" do
      it "returns next element" do
        expect(@enum.next == 1)
        expect(@enum.next == 2)
        expect(@enum.next == 3)
      end

      it "should raise stop iteration" do
        3.times { @enum.next }

        expect{ @enum.next }.to raise_error(StopIteration)
        expect{ @enum.next }.to raise_error(StopIteration)
      end

      it "can be called across threads" do
        result = []
        3.times { Thread.new { result << @enum.next }.join }

        expect([1, 2, 3] == result)
      end

      it "should propagate error from yielder" do
        enum = ThreadedEnum.new do |y|
          raise RuntimeError.new
        end

        expect{ enum.next }.to raise_error(RuntimeError)
      end

      it "can slow yield" do
        enum = ThreadedEnum.new do |y|
          (1..3).each { |n| sleep 0.01 ; y << n }
        end

        3.times { @enum.next }

        expect{ @enum.next }.to raise_error(StopIteration)
      end

      it "can slow poll" do
        3.times { sleep 0.01 ; @enum.next }

        expect{ @enum.next }.to raise_error(StopIteration)
        expect{ @enum.next }.to raise_error(StopIteration)
      end

      it "can construct from enumerable" do
        enum = ThreadedEnum.new([1, 2, 3])

        expect([1, 2, 3] == 3.times.map { enum.next })
        expect{ enum.next }.to raise_error(StopIteration)
      end

      it "should fail with both block and source" do
        expect{ ThreadedEnum.new([]) { } }.to raise_error(TypeError)
      end
    end
  end
end
