require 'acceptance/spec_helper'

describe 'SQL delta indexing', :live => true do
  def sleep_for_sphinx
    sleep ENV['CI'] ? 1.0 : 0.25
  end

  it "automatically indexes new records" do
    guards = Book.create(
      :title => 'Guards! Guards!', :author => 'Terry Pratchett'
    )
    index

    Book.search('Terry Pratchett').to_a.should == [guards]

    men = Book.create(
      :title => 'Men At Arms', :author => 'Terry Pratchett'
    )
    work
    sleep_for_sphinx

    Book.search('Terry Pratchett').to_a.should == [guards, men]
  end

  it "automatically indexes updated records" do
    book = Book.create :title => 'Night Watch', :author => 'Harry Pritchett'
    index

    Book.search('Harry').to_a.should == [book]

    book.reload.update_attributes(:author => 'Terry Pratchett')
    work
    sleep_for_sphinx

    Book.search('Terry').to_a.should == [book]
  end

  it "does not match on old values" do
    book = Book.create :title => 'Night Watch', :author => 'Harry Pritchett'
    index

    Book.search('Harry').to_a.should == [book]

    book.reload.update_attributes(:author => 'Terry Pratchett')
    work
    sleep_for_sphinx

    Book.search('Harry').should be_empty
  end
end
