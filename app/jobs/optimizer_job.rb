class OptimizerJob < ApplicationJob
  def perform(step_ids)
    @steps = Step.find(step_ids)

    @steps.each do |step|
      Optimizer.call(step)
    end
  end
end
