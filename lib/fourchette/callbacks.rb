class Fourchette::Callbacks
  def before
    logger.info 'Overriden callbacks...before!'
  end
  
  def after
    logger.info 'Overriden callbacks...after!'
  end
end