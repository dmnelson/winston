require "winston"

describe Winston::Variable do

  subject { described_class.new("my_var", value: 1, domain: [1, 2, 3]) }

  it { is_expected.to have_attributes(name: "my_var", value: 1, domain: [1, 2, 3]) }

  describe "#value=" do
    before { subject.value = "new value" }

    it { is_expected.to have_attributes(value: "new value") }
  end
end
