import React, { Component } from 'react'
import Search from './Search'
import Calculate from './Calculate'
import Portfolio from './Portfolio'
import axios from 'axios'


class PortfolioContainer extends Component {
  constructor(props){
    super(props)

    this.state = {
      name: '',
      portfolio: [],
      search_results: [],
      search_error: null,
      active_currency: null,
      amount: ''
    }

    this.handleChange = this.handleChange.bind(this)
    this.handleSelect = this.handleSelect.bind(this)
    this.handleSubmit = this.handleSubmit.bind(this)
    this.handleAmount = this.handleAmount.bind(this)
  }

  handleChange(e){
    axios.post('/search',{
      search: e.target.value
    })
    .then( (data) => {
      this.setState({
        search_results: [...data.data.currencies],
        search_error: null
      })
    })
    .catch( (error) =>   {
      const searchError = error.response && error.response.data && error.response.data.error
      const message = searchError && searchError.message
        ? searchError.message
        : 'Unable to search currencies right now. Please try again.'

      this.setState({
        search_results: [],
        search_error: message
      })
    }) 
  }

  handleSelect(e){
    e.preventDefault()
    const id = e.target.getAttribute('data-id')
    const activeCurrency = this.state.search_results.filter( item => item.id == parseInt(id))
    this.setState({
      active_currency: activeCurrency[0],
      search_results: [],
      search_error: null
    })
  }
    
  handleSubmit(e){
    e.preventDefault()

    let currency = this.state.active_currency
    let amount = this.state.amount

     axios.post('/calculate', {
      id: currency.id,
      amount: amount 
    })
    .then( (data) => {     
      this.setState({
        amount: '',
        active_currency: null,
        portfolio: [...this.state.portfolio, data.data]
      })
    })
    .catch( (err) => console.log(err))    
  }

  handleAmount(e){
    this.setState({
      [e.target.name]: e.target.value
    })
  }
 

  render(){
    const searchOrCalculate = this.state.active_currency ? 
    <Calculate
      handleChange={this.handleAmount}
      handleSubmit={this.handleSubmit}
      active_currency={this.state.active_currency}
      amount={this.state.amount}
    />:
    <Search 
    handleSelect={this.handleSelect} 
    searchResults={this.state.search_results}
    searchError={this.state.search_error}
    handleChange={this.handleChange} />

    return(
      <div className = "grid">
        <div className = "left">
          {searchOrCalculate}
        </div>
        <div className = "right">
          <Portfolio portfolio = {this.state.portfolio} />
        </div>       
      </div>
    )     
  }
}

export default PortfolioContainer