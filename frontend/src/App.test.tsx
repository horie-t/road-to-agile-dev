import { describe, it, expect, beforeEach, afterEach } from 'vitest'
import { createRoot } from 'react-dom/client'
import type { Root } from 'react-dom/client'
import { act } from 'react-dom/test-utils'
import App from './App'

let container: HTMLDivElement | null = null
let root: Root | null = null

beforeEach(() => {
  container = document.createElement('div')
  document.body.appendChild(container)
})

afterEach(() => {
  if (root) {
    act(() => {
      root!.unmount()
    })
  }
  if (container) {
    document.body.removeChild(container)
    container = null
  }
  root = null
})

describe('App', () => {
  it('renders and shows initial count', () => {
    act(() => {
      root = createRoot(container!)
      root.render(<App />)
    })

    const button = container!.querySelector('button')
    expect(button).toBeTruthy()
    expect(button!.textContent).toContain('count is 0')
  })

  it('increments count on click', () => {
    act(() => {
      root = createRoot(container!)
      root.render(<App />)
    })

    const button = container!.querySelector('button')!
    act(() => {
      button.dispatchEvent(new MouseEvent('click', { bubbles: true }))
    })

    expect(button.textContent).toContain('count is 1')
  })
})
