# manage a tb
class scaleio::tb {

  class{'scaleio::mdm::installation':
    is_tiebreaker => true,
  }
}
