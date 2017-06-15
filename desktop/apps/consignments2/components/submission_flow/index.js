import PropTypes from 'prop-types'
import React from 'react'
import StepMarker from '../step_marker'
import block from 'bem-cn'
import stepsConfig from '../../client/steps_config'
import { connect } from 'react-redux'
import {
  resizeWindow
} from '../../client/actions'

function SubmissionFlow (props) {
  const b = block('consignments2-submission-flow')
  const { CurrentStepComponent, isMobile } = props

  return (
    <div className={b({mobile: isMobile})}>
      <div className={b('title')}>
        Consign your work through Artsy in just a few quick steps
      </div>
      <StepMarker />
      <div className={b('step-form')}>
        <CurrentStepComponent />
      </div>
    </div>
  )
}

const mapStateToProps = (state) => {
  const {
    submissionFlow: {
      currentStep,
      isMobile
    }
  } = state

  return {
    CurrentStepComponent: stepsConfig[currentStep].component,
    isMobile
  }
}

const mapDispatchToProps = {
  responsiveWindowAction: resizeWindow
}

export default connect(
  mapStateToProps,
  mapDispatchToProps
)(SubmissionFlow)

SubmissionFlow.propTypes = {
  CurrentStepComponent: PropTypes.func.isRequired,
  isMobile: PropTypes.bool.isRequired
}
