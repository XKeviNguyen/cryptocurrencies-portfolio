import React, { Component } from 'react'

class Search extends Component {
  constructor(props){
    super(props)
  }

  render(){
    const searchResults = this.props.searchResults.map( curr => 
      <li key={curr.id} data-id={curr.id} onClick={this.props.handleSelect} className="currency-list-item"> 
      <a href="#" className="currency"> <span>{curr.currency_symbol}</span> <span>{curr.name}</span> </a>       
      </li>)
    return(
      <div>
        <h1> Cryptocurrencies Portfolio Calculator </h1>
        <form>
          <div className = "form-group">
            <label> Search for a Currency: </label><br/>
            <input onChange={this.props.handleChange} autoComplete="off" type="text" name="name" maxLength="80" placeholder="Ex: Bitcoin, Etherium, XRP,..." value={this.props.name} className="field"/>
            {this.props.searchError && <p role="alert" className="search-error">{this.props.searchError}</p>}
          </div>
          <div className = "currency-list">
            {searchResults}
          </div>
        </form>
      </div>
    )
  }
}

export default Search