# frozen_string_literal: true

RSpec.describe CompareLocalesSupport do
  describe 'check non english locales include all keys' do
    context 'when the source is English' do
      let(:source) { described_class::LOCALES_FILES[:english] }

      context 'when comparing to Spanish' do
        subject { described_class.compare(source, :spanish) }
        it { is_expected.to be_empty }
      end

      context 'when comparing to Portuguese' do
        subject { described_class.compare(source, :portuguese) }
        it { is_expected.to be_empty }
      end
    end
  end


  describe 'check non english devise locales include all keys' do
    context 'when the source is devise_english' do
      let(:source) { described_class::LOCALES_FILES[:devise_english] }

      context 'when comparing to devise_spanish' do
        subject { described_class.compare(source, :devise_spanish) }
        it { is_expected.to be_empty }
      end

      context 'when comparing to devise_portuguese' do
        subject { described_class.compare(source, :devise_portuguese) }
        it { is_expected.to be_empty }
      end
    end
  end


  describe 'check non english devise_invitable locales include all keys' do
    context 'when the source is devise_invitable_english' do
      let(:source) { described_class::LOCALES_FILES[:devise_invitable_english] }

      context 'when comparing to devise_invitable_spanish' do
        subject { described_class.compare(source, :devise_invitable_spanish) }
        it { is_expected.to be_empty }
      end

      context 'when comparing to devise_invitable_portuguese' do
        subject { described_class.compare(source, :devise_invitable_portuguese) }
        it { is_expected.to be_empty }
      end
    end
  end

  describe 'check non english kaminari_english locales include all keys' do
    context 'when the source is kaminari_spanish' do
      let(:source) { described_class::LOCALES_FILES[:kaminari_english] }

      context 'when comparing to kaminari_portuguese' do
        subject { described_class.compare(source, :kaminari_spanish) }
        it { is_expected.to be_empty }
      end

      context 'when comparing to devise_invitable_portuguese' do
        subject { described_class.compare(source, :kaminari_portuguese) }
        it { is_expected.to be_empty }
      end
    end
  end


  describe 'check all locale files for missing tests' do
    subject{Dir.glob("#{described_class::LOCALES_DIR}/*.yml")}
    it { is_expected.to match_array(described_class::LOCALES_FILES.values) }
  end
end
