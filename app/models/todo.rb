# frozen_string_literal: true

class Todo < ApplicationRecord
  # attr_accessor :completed ## should just be a possible status of the enum 
  # Add db field and model string enum to track status more effectively 
  # decouple status methods from each other, use enum built in methods 

  belongs_to :todo_list, required: true, inverse_of: :todos

  has_one :user, through: :todo_list

  enum :status, { pending: 0, in_progress: 1, completed: 2 }, default: :pending

  # these should use status string enum for better queries and less logic 
  scope :overdue, -> { where('due_at <= ?', Time.current) }
  scope :completed, -> { where.not(completed_at: nil) }
  scope :incomplete, -> { where(status: "incomplete") }

  scope :filter_by_status, ->(params) {
    case params[:status]&.strip&.downcase
    when 'overdue' then overdue
    when 'completed' then completed
    when 'incomplete' then incomplete
    else all
    end
  }

  # Could refactor order by scope into a shared concern between models
  scope :order_by, ->(params) {
    order = params[:order]&.strip&.downcase == 'asc' ? :asc : :desc

    sort_by = params[:sort_by]&.strip&.downcase

    column_name = column_names.excluding('id').include?(sort_by) ? sort_by : 'id'

    order(column_name => order)
  }

  before_validation on: :update do
    case completed
    when 'true' then complete
    when 'false' then incomplete
    end
  end

  validates :title, presence: true
  validates :due_at, presence: true, allow_nil: true
  validates :completed_at, presence: true, allow_nil: true

  def overdue?
    return false if !due_at || completed_at

    due_at <= Time.current
  end

  def incomplete?
    completed_at.nil?
  end

  def completed?
    !incomplete?
  end

  def status
    return 'completed' if completed?
    return 'overdue' if overdue?

    'incomplete'
  end

  def complete
    self.completed_at = Time.current unless completed?
  end

  def complete!
    complete

    self.save if completed_at_changed?
  end

  def incomplete
    self.completed_at = nil unless incomplete?
  end

  def incomplete!
    incomplete

    self.save if completed_at_changed?
  end

  def serialize_as_json
    as_json(except: [:completed], methods: :status)
  end
end
